//
//  NotificationsSetting.swift
//  AzureCommunicationVideoCallingSample
//
//  Created by Hyounwoo Sung on 2021/02/08.
//

import SwiftUI
import WindowsAzureMessaging

struct NotificationsSetting: View {
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    @State var tag: String = "";

    var body: some View {
        VStack(alignment: .leading) {
            Text("Device Token:")
                .font(.headline)
                .padding(.leading)
            Text(notificationViewModel.pushChannel)
                .font(.footnote)
                .foregroundColor(Color.gray)
                .padding([.leading, .bottom, .trailing])

            Text("Installation ID:")
                .font(.headline)
                .padding(.leading)
            Text(notificationViewModel.installationId)
                .font(.footnote)
                .foregroundColor(Color.gray)
                .padding([.leading, .bottom, .trailing])

            Text("User ID:")
                .font(.headline)
                .padding(.leading)
            TextField("Set User ID", text: $notificationViewModel.userId, onEditingChanged: {focus in
                if(!focus) {
                    notificationViewModel.setUserId()
                }
            })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding([.leading, .bottom, .trailing])

            Text("Tags:")
                .font(.headline)
                .padding(.leading)
            TextField("Add new tag", text: $tag, onCommit: {
                if(self.tag != "") {
                    notificationViewModel.addTag(tag: self.tag)
                    self.tag = ""
                }
            })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding([.leading, .bottom, .trailing])

            TagsList(tags: notificationViewModel.tags, onDelete: {
                $0.forEach({
                    MSNotificationHub.removeTag(notificationViewModel.tags.remove(at: $0));
                })
            })

            Spacer()
        }
    }
}

struct NotificationsSetting_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsSetting()
            .environmentObject(NotificationViewModel())
    }
}
